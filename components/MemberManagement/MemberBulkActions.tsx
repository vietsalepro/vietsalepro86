import React, { useState } from 'react';
import { Users, UserCog, Power, PowerOff, Trash2 } from 'lucide-react';
import { ActionButton } from '../ActionButton';
import { SelectInput } from '../SelectInput';
import { MasterModal } from '../MasterModal';
import { useConfirmDialog } from '../../hooks/useConfirmDialog';
import { useToast } from '../ToastContainer';
import { MemberWithEmail, TenantRole } from '../../types/tenant';
import { updateMemberRole, toggleMemberActive, removeMember } from '../../services/tenantService';

interface MemberBulkActionsProps {
  tenantId?: string;
  selectedMembers: MemberWithEmail[];
  onAction: () => void | Promise<void>;
  disabled?: boolean;
}

const ROLES: { value: TenantRole; label: string }[] = [
  { value: 'admin', label: 'Admin' },
  { value: 'cashier', label: 'Thu ngân' },
  { value: 'inventory_manager', label: 'Quản lý kho' },
  { value: 'accountant', label: 'Kế toán' },
];

const roleLabel = (role: TenantRole) => ROLES.find((r) => r.value === role)?.label || role;

export const MemberBulkActions: React.FC<MemberBulkActionsProps> = ({
  tenantId,
  selectedMembers,
  onAction,
  disabled = false,
}) => {
  const [roleModalOpen, setRoleModalOpen] = useState(false);
  const [newRole, setNewRole] = useState<TenantRole>('cashier');
  const [processing, setProcessing] = useState(false);
  const { openConfirmDialog, confirmDialog } = useConfirmDialog();
  const { addToast } = useToast();

  const hasOwner = selectedMembers.some((m) => m.isOwner);
  const count = selectedMembers.length;
  if (!tenantId || count === 0) return null;
  const tId = tenantId;

  const runSequential = async (fn: (member: MemberWithEmail) => Promise<unknown>, successMessage: string) => {
    setProcessing(true);
    try {
      for (const member of selectedMembers) {
        await fn(member);
      }
      addToast({ type: 'success', message: successMessage });
      onAction();
    } catch (err: any) {
      addToast({ type: 'error', message: err?.message || 'Thao tác thất bại.' });
    } finally {
      setProcessing(false);
    }
  };

  const handleChangeRole = () => {
    openConfirmDialog({
      title: 'Đổi vai trò hàng loạt',
      message: `Đổi vai trò ${count} thành viên thành "${roleLabel(newRole)}"?`,
      variant: 'warning',
      onConfirm: async () => {
        await runSequential(
          (m) => updateMemberRole(tId, m.userId, newRole),
          `Đã đổi vai trò ${count} thành viên.`,
        );
        setRoleModalOpen(false);
      },
    });
  };

  const handleActivate = () => {
    openConfirmDialog({
      title: 'Kích hoạt thành viên',
      message: `Kích hoạt ${count} thành viên đã chọn?`,
      variant: 'info',
      onConfirm: () => runSequential(
        (m) => toggleMemberActive(tId, m.userId, true),
        `Đã kích hoạt ${count} thành viên.`,
      ),
    });
  };

  const handleDeactivate = () => {
    openConfirmDialog({
      title: 'Vô hiệu hóa thành viên',
      message: `Vô hiệu hóa ${count} thành viên đã chọn?`,
      variant: 'warning',
      onConfirm: () => runSequential(
        (m) => toggleMemberActive(tId, m.userId, false),
        `Đã vô hiệu hóa ${count} thành viên.`,
      ),
    });
  };

  const handleRemove = () => {
    openConfirmDialog({
      title: 'Xóa thành viên',
      message: `Xóa ${count} thành viên đã chọn khỏi cửa hàng? Thao tác này không thể hoàn tác.`,
      variant: 'danger',
      onConfirm: () => runSequential(
        (m) => removeMember(tId, m.userId),
        `Đã xóa ${count} thành viên.`,
      ),
    });
  };

  return (
    <div className="flex items-center gap-2">
      <div className="flex items-center gap-1 text-sm text-gray-600 mr-2">
        <Users size={16} />
        <span>{count} đã chọn</span>
      </div>
      <ActionButton
        size="sm"
        variant="secondary"
        icon={<UserCog size={16} />}
        onClick={() => setRoleModalOpen(true)}
        disabled={disabled || processing || hasOwner}
        title={hasOwner ? 'Không thể đổi vai trò chủ sở hữu' : undefined}
      >
        Đổi vai trò
      </ActionButton>
      <ActionButton
        size="sm"
        variant="secondary"
        icon={<Power size={16} />}
        onClick={handleActivate}
        disabled={disabled || processing}
      >
        Kích hoạt
      </ActionButton>
      <ActionButton
        size="sm"
        variant="secondary"
        icon={<PowerOff size={16} />}
        onClick={handleDeactivate}
        disabled={disabled || processing}
      >
        Khóa
      </ActionButton>
      <ActionButton
        size="sm"
        variant="danger"
        icon={<Trash2 size={16} />}
        onClick={handleRemove}
        disabled={disabled || processing || hasOwner}
        title={hasOwner ? 'Không thể xóa chủ sở hữu' : undefined}
      >
        Xóa
      </ActionButton>

      {roleModalOpen && (
        <MasterModal
          isOpen
          onClose={() => setRoleModalOpen(false)}
          title="Chọn vai trò mới"
          size="sm"
          footer={
            <div className="flex justify-end gap-2">
              <ActionButton variant="ghost" onClick={() => setRoleModalOpen(false)} disabled={processing}>
                Hủy
              </ActionButton>
              <ActionButton variant="primary" onClick={handleChangeRole} disabled={processing}>
                Xác nhận
              </ActionButton>
            </div>
          }
        >
          <SelectInput
            label="Vai trò mới"
            options={ROLES}
            value={newRole}
            onChange={(e) => setNewRole(e.target.value as TenantRole)}
            fullWidth
          />
        </MasterModal>
      )}
      {confirmDialog}
    </div>
  );
};
